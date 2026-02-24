WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
), 
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(vt.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS QuestionAnswers
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vt ON p.Id = vt.PostId
    GROUP BY 
        p.OwnerUserId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ups.PostCount,
    ups.TotalVotes,
    ups.QuestionAnswers,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN ph.PostId IS NOT NULL THEN p.Id END) AS EditedPosts,
    STRING_AGG(DISTINCT ub.BadgeName, ', ') AS Badges,
    MAX(CASE WHEN ub.Class = 1 THEN 'Gold' 
             WHEN ub.Class = 2 THEN 'Silver' 
             WHEN ub.Class = 3 THEN 'Bronze' 
             ELSE 'No Badge' END) AS HighestBadge
FROM 
    Users u
JOIN 
    UserPostStats ups ON u.Id = ups.OwnerUserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistories ph ON p.Id = ph.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId AND ub.BadgeRank = 1
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, ups.PostCount, ups.TotalVotes, ups.QuestionAnswers
HAVING 
    COUNT(DISTINCT p.Id) > 10 
ORDER BY 
    u.Reputation DESC
LIMIT 50;