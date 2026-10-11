(function veloraSpotifyBridge() {
    const ENDPOINT = "http://127.0.0.1:8765";
    const FALLBACK_INTERVAL = 5000;

    let lastSignature = "";

    function waitForSpotify() {
        if (
            !window.Spicetify ||
            !Spicetify.Player ||
            !Spicetify.Player.data ||
            !Spicetify.Queue
        ) {
            setTimeout(waitForSpotify, 500);
            return;
        }

        console.log("[Velora Spotify] bridge ready");
        start();
    }

    function first(...values) {
        for (const value of values) {
            if (
                value !== undefined &&
                value !== null &&
                value !== ""
            )
                return value;
        }

        return "";
    }

    function unwrap(track) {
        if (!track)
            return null;

        return (
            track.item ||
            track.track ||
            track.contextTrack ||
            track.context_track ||
            track.data ||
            track
        );
    }

    function artistName(track) {
        const t = unwrap(track);

        if (!t)
            return "";

        if (Array.isArray(t.artists)) {
            const artists = t.artists
                .map(a => typeof a === "string" ? a : a?.name || "")
                .filter(Boolean);

            if (artists.length)
                return artists.join(", ");
        }

        const m = t.metadata || track?.metadata || {};

        return String(first(
            m.artist_name,
            m.album_artist_name,
            m.artist,
            t.artistName,
            t.artist,
            ""
        ));
    }

    function albumName(track) {
        const t = unwrap(track);

        if (!t)
            return "";

        if (typeof t.album === "string")
            return t.album;

        const m = t.metadata || track?.metadata || {};

        return String(first(
            t.album?.name,
            m.album_title,
            m.album_name,
            m.album,
            ""
        ));
    }

    function artwork(track) {
        const t = unwrap(track);

        if (!t)
            return "";

        if (Array.isArray(t.images) && t.images.length) {
            const image = t.images[0];

            if (typeof image === "string")
                return image;

            if (image?.url)
                return image.url;
        }

        if (
            t.album &&
            Array.isArray(t.album.images) &&
            t.album.images.length
        )
            return t.album.images[0]?.url || "";

        const m = t.metadata || track?.metadata || {};

        return String(first(
            m.image_xlarge_url,
            m.image_large_url,
            m.image_url,
            m.image_small_url,
            ""
        ));
    }

    function normalize(track) {
        const t = unwrap(track);

        if (!t)
            return null;

        const m = t.metadata || track?.metadata || {};

        return {
            uri: String(first(
                t.uri,
                track?.uri,
                m.uri,
                ""
            )),

            title: String(first(
                t.name,
                t.title,
                m.title,
                m.name,
                ""
            )),

            artist: artistName(track),

            album: albumName(track),

            art: artwork(track),

            duration: Number(first(
                t.duration,
                t.duration_ms,
                m.duration,
                m.duration_ms,
                0
            ))
        };
    }

    function buildPayload() {
        const player = Spicetify.Player.data;
        const queue = Spicetify.Queue;

        let rawNext = [];

        if (
            Array.isArray(queue.nextTracks) &&
            queue.nextTracks.length
        ) {
            rawNext = queue.nextTracks;
        } else if (
            Array.isArray(player.nextItems)
        ) {
            rawNext = player.nextItems;
        }

        return {
            version: 1,
            timestamp: Date.now(),

            revision:
                String(queue.queueRevision || ""),

            playing:
                !player.isPaused,

            position:
                Number(
                    player.positionAsOfTimestamp || 0
                ),

            current:
                normalize(player.item)
                || normalize(queue.track),

            next:
                rawNext
                    .map(normalize)
                    .filter(track =>
                        track &&
                        (track.title || track.uri)
                    )
        };
    }

    async function sync(force = false) {
        try {
            const payload = buildPayload();

            const signature = JSON.stringify({
                revision: payload.revision,
                playing: payload.playing,
                current: payload.current?.uri || "",
                queue: payload.next.map(t => t.uri).join("|")
            });

            if (!force && signature === lastSignature)
                return;

            lastSignature = signature;

            const response = await fetch(
                ENDPOINT,
                {
                    method: "POST",
                    headers: {
                        "Content-Type":
                            "application/json"
                    },
                    body: JSON.stringify(payload)
                }
            );

            console.log(
                "[Velora Spotify]",
                payload.next.length,
                "queued",
                response.status
            );

        } catch (error) {
            console.error(
                "[Velora Spotify]",
                error
            );
        }
    }

    function start() {
        sync(true);

        Spicetify.Player.addEventListener(
            "songchange",
            () => setTimeout(() => sync(true), 300)
        );

        Spicetify.Player.addEventListener(
            "onplaypause",
            () => setTimeout(() => sync(true), 100)
        );

        setInterval(
            () => sync(false),
            FALLBACK_INTERVAL
        );
    }

    waitForSpotify();
})();

// Search stays inside the authenticated Spotify client. The bridge exchanges
// normalized track metadata only, never access tokens or account credentials.
// https://spicetify.app/docs/development/api-wrapper/methods/cosmos-async
(function veloraCatalogue() {
    const endpoint = "http://127.0.0.1:8765";
    async function catalogue(query) {
        try {
            const response = await Spicetify.CosmosAsync.get(
                "https://api.spotify.com/v1/search?type=track&limit=15&q=" + encodeURIComponent(query));
            if (response?.tracks?.items) return response.tracks.items.map(track => ({
                uri: track.uri, title: track.name,
                artist: (track.artists || []).map(artist => artist.name).join(", "),
                album: track.album?.name || "", art: track.album?.images?.[0]?.url || "",
                duration: track.duration_ms || 0
            }));
        } catch (_) { /* Use the client search when the Web API is unavailable. */ }
        const api = Spicetify.GraphQL;
        if (!api?.Definitions?.searchDesktop) throw new Error("search-unavailable");
        const response = await api.Request(api.Definitions.searchDesktop, {
            searchTerm: query, offset: 0, limit: 15, numberOfTopResults: 5,
            includeAudiobooks: false, includeArtistHasConcertsField: false, includePreReleases: false
        });
        const items = response?.data?.searchV2?.tracksV2?.items;
        if (!Array.isArray(items)) throw new Error("search-unavailable");
        return items.map(item => item.item?.data || item.item || item.data).filter(Boolean).map(track => ({
            uri: track.uri, title: track.name,
            artist: (track.artists?.items || []).map(artist => artist.profile?.name || artist.name || "").join(", "),
            album: track.albumOfTrack?.name || "",
            art: track.albumOfTrack?.coverArt?.sources?.[0]?.url || "",
            duration: track.duration?.totalMilliseconds || 0
        }));
    }
    async function listen() {
        if (!window.Spicetify?.CosmosAsync) { setTimeout(listen, 1000); return; }
        try {
            const response = await fetch(endpoint + "/requests");
            if (!response.ok) throw new Error("bridge-offline");
            const payload = await response.json();
            for (const request of payload.requests || []) {
                let result;
                try { result = { id: request.id, ok: true, tracks: await catalogue(request.query) }; }
                catch (_) { result = { id: request.id, ok: false, reason: "search-unavailable", tracks: [] }; }
                await fetch(endpoint + "/result", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(result) });
            }
            setTimeout(listen, 100);
        } catch (_) { setTimeout(listen, 3000); }
    }
    listen();
})();
