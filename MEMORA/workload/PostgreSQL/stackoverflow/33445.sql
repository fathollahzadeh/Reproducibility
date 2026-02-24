WITH RECURSIVE PostHierarchy AS (
    
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
    WHERE 
        p.PostTypeId = 2 
),
BadgeCounts AS (
    
    SELECT 
        UserId,
        COUNT(*) as BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserVotes AS (
    
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
UserRankings AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        (u.Reputation + COALESCE(bc.BadgeCount, 0) * 10) AS Score, 
        ROW_NUMBER() OVER (ORDER BY (u.Reputation + COALESCE(bc.BadgeCount, 0) * 10) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        BadgeCounts bc ON u.Id = bc.UserId
),
HottestPosts AS (
    
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount + p.Score DESC) AS HotRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
      AND 
        p.ClosedDate IS NULL 
)
SELECT 
    ph.Title AS QuestionTitle,
    u.DisplayName AS Respondent,
    up.UpVotesCount,
    up.DownVotesCount,
    hp.ViewCount AS QuestionViewCount,
    hp.Score AS QuestionScore,
    u.Rank AS UserRank,
    ph.Level AS ResponseLevel
FROM 
    PostHierarchy ph
JOIN 
    Posts p ON ph.ParentId = p.Id 
JOIN 
    UserVotes up ON p.OwnerUserId = up.UserId
JOIN 
    UserRankings u ON p.OwnerUserId = u.UserId
JOIN 
    HottestPosts hp ON hp.Id = p.Id
WHERE 
    u.Score >= 50 
ORDER BY 
    u.Rank, ph.Level;