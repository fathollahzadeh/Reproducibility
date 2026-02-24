WITH RecursiveUserPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
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
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
    GROUP BY 
        v.PostId
),
TopQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Score AS QuestionScore,
        COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
        COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ub.BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecentVotes rv ON p.Id = rv.PostId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        p.PostTypeId = 1  
        AND (p.Score >= 10 OR ub.BadgeCount >= 3) 
),
TopActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    WHERE 
        PostTypeId IN (1, 2)  
    GROUP BY 
        OwnerUserId
    HAVING
        COUNT(*) > 5  
)
SELECT 
    tq.QuestionId,
    tq.Title,
    tq.QuestionScore,
    tq.RecentUpVotes,
    tq.RecentDownVotes,
    tq.OwnerDisplayName,
    tq.BadgeCount,
    tu.PostCount,
    tu.TotalScore,
    ROW_NUMBER() OVER (ORDER BY tq.QuestionScore DESC, tq.RecentUpVotes DESC) AS Ranking
FROM 
    TopQuestions tq
JOIN 
    TopActiveUsers tu ON tq.OwnerUserId = tu.OwnerUserId
ORDER BY 
    Ranking;