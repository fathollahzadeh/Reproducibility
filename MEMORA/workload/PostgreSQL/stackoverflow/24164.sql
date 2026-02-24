WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalVotes, 
        UpVotes, 
        DownVotes, 
        QuestionCount, 
        AnswerCount, 
        BadgeCount, 
        RANK() OVER (ORDER BY TotalVotes DESC, UpVotes DESC) AS VoteRank
    FROM UserVoteStats
), RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate,
        p.Score, 
        COALESCE(
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 
            0
        ) AS CommentCount,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS EngagedPosts,
        SUM(COALESCE(v.VoteTypeId, 0)) AS VotingActivity,
        AVG(p.Score) AS AvgPostScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
), FinalResult AS (
    SELECT 
        ru.DisplayName,
        ru.TotalVotes,
        ru.UpVotes,
        ru.DownVotes,
        ru.QuestionCount,
        ru.AnswerCount,
        ru.BadgeCount,
        rps.Title AS RecentPostTitle,
        rps.PostStatus,
        ue.EngagedPosts,
        ue.VotingActivity,
        ue.AvgPostScore
    FROM RankedUsers ru
    LEFT JOIN RecentPostStats rps ON ru.UserId = rps.PostId  
    LEFT JOIN UserEngagement ue ON ru.UserId = ue.UserId
)
SELECT 
    *,
    CASE 
        WHEN BadgeCount > 10 AND UpVotes > DownVotes THEN 'Prominent User'
        ELSE 'Regular User' 
    END AS UserCategory
FROM FinalResult
WHERE EngagedPosts > 5
ORDER BY TotalVotes DESC, UpVotes DESC;