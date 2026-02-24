
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT 
            unnest(string_to_array(p.Tags, '><')) AS TagName) AS t ON TRUE
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Score
), 
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), 
PostHistoryFlags AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS IsDeleted
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ps.UpVotes,
    ps.DownVotes,
    ph.IsClosed,
    ph.IsReopened,
    ph.IsDeleted,
    rp.CommentCount,
    rp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN 
    PostHistoryFlags ph ON rp.PostId = ph.PostId
WHERE 
    rp.ScoreRank <= 5 AND
    (ph.IsClosed IS NULL OR ph.IsClosed = 0)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
