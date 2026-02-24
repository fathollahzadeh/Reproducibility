
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        CASE 
            WHEN p.Score IS NULL THEN 'No Score'
            WHEN p.Score > 0 THEN 'Positive Score'
            ELSE 'Negative Score' 
        END AS ScoreCategory,
        COALESCE(lp.LinkTypeId, 0) AS LinkCategory 
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostLinks lp ON p.Id = lp.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
        AND (p.Tags LIKE '%SQL%' OR p.Title LIKE '%SQL%')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId, lp.LinkTypeId
),

TopRankedPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerName,
        bt.Name AS BadgeName
    FROM 
        RankedPosts rp
    JOIN Users u ON rp.PostId = u.Id
    LEFT JOIN Badges bt ON u.Id = bt.UserId AND bt.Class = 1 
    WHERE 
        rp.PostRank <= 5
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    UpVotes,
    DownVotes,
    CASE 
        WHEN LinkCategory = 1 THEN 'Linked'
        WHEN LinkCategory = 3 THEN 'Duplicate'
        ELSE 'No Link'
    END AS LinkStatus,
    OwnerName,
    BadgeName,
    RANK() OVER (ORDER BY Score DESC) AS OverallRank
FROM 
    TopRankedPosts
WHERE 
    OwnerName IS NOT NULL 
ORDER BY 
    OverallRank, PostId
LIMIT 50;
