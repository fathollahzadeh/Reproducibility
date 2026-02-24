WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS HasGoldBadge
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId AND c.UserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(AVG(p.Score), 0) AS AvgScore,
        MAX(p.CreationDate) AS LatestQuestion
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1
    GROUP BY p.OwnerUserId
),
ReflectiveMetrics AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.UpVotes,
        ue.DownVotes,
        qs.QuestionCount,
        qs.AnswerCount,
        qs.AvgScore,
        qs.LatestQuestion,
        CASE 
            WHEN qs.QuestionCount > 10 THEN 'Active Contributor'
            WHEN qs.AnswerCount > 20 THEN 'Question Expert'
            ELSE 'Newbie'
        END AS UserType,
        ROW_NUMBER() OVER (ORDER BY ue.UpVotes DESC) AS VoteRank
    FROM UserEngagement ue
    LEFT JOIN QuestionStats qs ON ue.UserId = qs.OwnerUserId
)
SELECT 
    rm.UserId,
    rm.DisplayName,
    rm.UpVotes,
    rm.DownVotes,
    rm.QuestionCount,
    rm.AnswerCount,
    rm.AvgScore,
    rm.LatestQuestion,
    rm.UserType,
    COALESCE(STRING_AGG(DISTINCT b.Name, ', '), 'No Badges') AS Badges
FROM ReflectiveMetrics rm
LEFT JOIN Badges b ON rm.UserId = b.UserId
GROUP BY 
    rm.UserId, 
    rm.DisplayName, 
    rm.UpVotes, 
    rm.DownVotes, 
    rm.QuestionCount, 
    rm.AnswerCount, 
    rm.AvgScore, 
    rm.LatestQuestion, 
    rm.UserType
HAVING 
    (rm.UpVotes - rm.DownVotes) > 5    
    OR (rm.QuestionCount > 0)           
UNION
SELECT 
    -1 AS UserId, 
    'System' AS DisplayName,
    0 AS UpVotes,
    0 AS DownVotes,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    0 AS AvgScore,
    NULL AS LatestQuestion,
    'No Rank' AS UserType,
    'System Badge' AS Badges
FROM Posts p
WHERE p.OwnerUserId = -1
GROUP BY p.OwnerUserId
ORDER BY UpVotes DESC, QuestionCount DESC;