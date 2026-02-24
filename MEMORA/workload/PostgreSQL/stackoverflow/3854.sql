
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title
),
FinalResults AS (
    SELECT 
        up.UserId,
        CASE 
            WHEN up.Reputation < 1000 THEN 'Bronze Level'
            WHEN up.Reputation BETWEEN 1000 AND 5000 THEN 'Silver Level'
            ELSE 'Gold Level'
        END AS ReputationLevel,
        rp.Title AS LastQuestion,
        rp.CreationDate AS LastQuestionDate,
        rp.Score AS LastQuestionScore,
        COALESCE(pwc.CommentCount, 0) AS LastQuestionComments
    FROM 
        UserReputation up
    JOIN 
        RankedPosts rp ON up.UserId = rp.OwnerUserId
    LEFT JOIN 
        PostsWithComments pwc ON rp.PostId = pwc.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    fr.UserId,
    fr.ReputationLevel,
    fr.LastQuestion,
    fr.LastQuestionDate,
    fr.LastQuestionScore,
    fr.LastQuestionComments
FROM 
    FinalResults fr
ORDER BY 
    fr.ReputationLevel DESC, fr.LastQuestionScore DESC
LIMIT 100;
