
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 12 THEN 1 ELSE 0 END), 0) AS SpamReports
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastModified,
        STRING_AGG(ph.Comment, ', ') AS CommentsMade,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    ra.UserId,
    ra.DisplayName,
    ra.VoteCount,
    ra.UpvoteCount,
    ra.SpamReports,
    phd.LastModified,
    phd.CommentsMade,
    phd.HistoryCount
FROM 
    RankedPosts rp
INNER JOIN 
    RecentActivity ra ON ra.VoteCount > 10
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId
WHERE 
    rp.ScoreRank < 5 
    AND (
        rp.PostTypeId = 1 OR
        (rp.PostTypeId = 2 AND rp.ViewCount > 100)
    )
ORDER BY 
    rp.Score DESC, ra.UpvoteCount ASC
FETCH FIRST 100 ROWS ONLY;
