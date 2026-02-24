
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
QuestionRatings AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        ur.TotalBadges,
        CASE 
            WHEN ur.Reputation >= 1000 THEN 'High Reputation' 
            WHEN ur.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation' 
            ELSE 'Low Reputation' 
        END AS ReputationCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.RN = 1 
)
SELECT 
    q.PostId,
    q.Title,
    q.CreationDate,
    q.Score,
    q.ViewCount,
    q.Reputation,
    q.TotalBadges,
    q.ReputationCategory,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN q.Score > 10 THEN 'Popular'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    QuestionRatings q
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON q.PostId = c.PostId
ORDER BY 
    q.Reputation DESC, 
    q.Score DESC
FETCH FIRST 100 ROWS ONLY;
