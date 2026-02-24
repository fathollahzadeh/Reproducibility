
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= ('2024-10-01 12:34:56'::timestamp - INTERVAL '1 year')
),
PostCommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        pcs.CommentCount,
        pcs.AverageCommentScore,
        pb.BadgeCount,
        CASE 
            WHEN rp.RankScore <= 5 THEN 'Top 5'
            WHEN rp.RankScore <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS RankCategory,
        rp.RecentPostRank  -- added to SELECT since it's used in the final ORDER BY
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCommentStats pcs ON rp.PostId = pcs.PostId
    LEFT JOIN 
        PostBadgeCount pb ON rp.OwnerDisplayName IN (SELECT U.DisplayName FROM Users U WHERE U.Id = pb.UserId)  -- modified join condition
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    *,
    (Score + ViewCount + COALESCE(CommentCount, 0) + COALESCE(AverageCommentScore, 0) + COALESCE(BadgeCount, 0)) AS EngagementScore
FROM 
    FinalResults
ORDER BY 
    EngagementScore DESC, RecentPostRank ASC;
