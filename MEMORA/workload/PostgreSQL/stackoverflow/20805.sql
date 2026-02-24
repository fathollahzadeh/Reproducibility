WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        MAX(p.Score) AS MaxPostScore
    FROM 
        Users u
    LEFT JOIN 
        (SELECT 
            UserId, 
            COUNT(Id) AS BadgeCount
         FROM 
            Badges
         GROUP BY UserId) b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, b.BadgeCount
),
UserPostDetails AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerPostRank,
        p.VoteCount,
        p.UpVoteCount,
        p.DownVoteCount
    FROM 
        UserStats us
    JOIN 
        RankedPosts p ON us.UserId = p.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    up.Title,
    CASE 
        WHEN up.OwnerPostRank = 1 THEN 'Most Recent Post'
        ELSE 'Older Post'
    END AS PostStatus,
    up.Score,
    up.VoteCount,
    up.UpVoteCount,
    up.DownVoteCount,
    DATE_PART('year', AGE(up.CreationDate)) AS PostAgeInYears,
    CASE 
        WHEN up.Score > 10 THEN 'High Score'
        WHEN up.Score BETWEEN 5 AND 10 THEN 'Moderate Score'
        WHEN up.Score < 5 THEN 'Low Score'
        ELSE 'No Score'
    END AS ScoreCategory
FROM 
    UserPostDetails up
WHERE 
    up.Reputation > 100
ORDER BY 
    up.Reputation DESC, 
    up.Score DESC
LIMIT 50;