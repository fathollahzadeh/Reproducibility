
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
TopPostStats AS (
    SELECT 
        PostId,
        Title,
        Author,
        CreationDate,
        ViewCount,
        Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        ScoreRank = 1
), 
PostHistoryAggregate AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
), 
PostLinkStats AS (
    SELECT 
        pl.PostId,
        COUNT(*) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    tps.PostId,
    tps.Title,
    tps.Author,
    tps.CreationDate,
    tps.ViewCount,
    tps.Score,
    tps.CommentCount,
    tps.UpvoteCount,
    tps.DownvoteCount,
    COALESCE(pla.RelatedPostCount, 0) AS RelatedPostCount,
    (SELECT STRING_AGG(DISTINCT CASE WHEN pt.Name IS NOT NULL THEN pt.Name END, ', ') 
      FROM PostHistory ph 
      LEFT JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id 
      WHERE ph.PostId = tps.PostId) AS HistoryTypes,
    COALESCE(ha.LastChangeDate, TIMESTAMP '1970-01-01 00:00:00') AS LastChange
FROM 
    TopPostStats tps
LEFT JOIN 
    PostLinkStats pla ON tps.PostId = pla.PostId
LEFT JOIN 
    PostHistoryAggregate ha ON tps.PostId = ha.PostId
WHERE 
    tps.Score > 0 
ORDER BY 
    tps.Score DESC, tps.ViewCount DESC;
