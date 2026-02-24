WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
), 
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        CASE 
            WHEN rp.Score >= 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 5 AND 9 THEN 'Medium Score'
            ELSE 'Low Score' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT PostId FROM TopQuestions)
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.BadgeCount,
    ua.TotalBounties,
    tq.Title,
    tq.ViewCount,
    tq.Score,
    tq.CommentCount,
    CASE 
        WHEN ua.BadgeCount > 5 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributionLevel
FROM 
    UserActivity ua
INNER JOIN 
    TopQuestions tq ON ua.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tq.PostId LIMIT 1)
ORDER BY 
    ua.TotalBounties DESC, tq.Score DESC;
