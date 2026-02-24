
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),

HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank <= 5  
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Score AS TotalScore,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Score
)

SELECT 
    u.DisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    hsp.Title,
    hsp.Score AS PostScore,
    hsp.ViewCount,
    hsp.CommentCount,
    ps.TotalScore,
    ps.Upvotes,
    ps.Downvotes,
    ps.TotalVotes
FROM 
    HighScoringPosts hsp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = hsp.PostId)  
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
JOIN 
    PostScores ps ON ps.PostId = hsp.PostId
ORDER BY 
    hsp.Score DESC, 
    ub.BadgeCount DESC;
