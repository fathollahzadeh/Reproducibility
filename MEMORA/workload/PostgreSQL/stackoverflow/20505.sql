
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2020-01-01 00:00:00'
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date AS ObtainedDate,
        DENSE_RANK() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 100
),
QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    bs.BadgeName,
    tu.DisplayName,
    tu.Reputation,
    qs.TotalComments,
    qs.Upvotes,
    qs.Downvotes,
    CASE 
        WHEN qs.TotalComments IS NULL THEN 'No Comments'
        ELSE CONCAT(qs.TotalComments, ' comments')
    END AS CommentInfo,
    CASE 
        WHEN rp.ViewCount > 100 THEN 'Highly Viewed'
        ELSE 'Low Views'
    END AS ViewCategory,
    COALESCE(tu.UserRank, 9999) AS UserRankFallback,
    CASE 
        WHEN rp.Score IS NULL THEN 'Score Not Found'
        ELSE CONCAT('Score: ', rp.Score)
    END AS ScoreInfo
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges bs ON bs.UserId = rp.PostId
LEFT JOIN 
    TopUsers tu ON tu.UserId = rp.PostId
LEFT JOIN 
    QuestionStats qs ON qs.QuestionId = rp.PostId
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;
