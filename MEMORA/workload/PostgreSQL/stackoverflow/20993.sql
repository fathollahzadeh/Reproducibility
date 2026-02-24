WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
VotesSummary AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
),
CombinedStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS TotalQuestions,
        COALESCE(ps.Answers, 0) AS TotalAnswers,
        COALESCE(vs.TotalVotes, 0) AS TotalVotes,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        u.Reputation
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN VotesSummary vs ON u.Id = vs.UserId
),
RankedStats AS (
    SELECT 
        cs.*,
        ROW_NUMBER() OVER (ORDER BY cs.Reputation DESC, cs.BadgeCount DESC, cs.TotalPosts DESC) AS Rank
    FROM CombinedStats cs
)
SELECT 
    r.UserId,
    r.Rank,
    r.Reputation,
    r.BadgeCount,
    r.TotalPosts,
    r.TotalQuestions,
    r.TotalAnswers,
    r.TotalVotes,
    r.UpVotes,
    r.DownVotes,
    CASE 
        WHEN r.TotalPosts > 0 THEN 'Active'
        ELSE 'Inactive' 
    END AS ActivityStatus,
    CONCAT('User ', r.UserId, ' has a reputation of ', r.Reputation,
           ' with ', r.BadgeCount, ' badges, and ', r.TotalPosts, ' posts.') AS UserSummary
FROM RankedStats r
WHERE r.Reputation IS NOT NULL
ORDER BY r.Rank, r.UserId;
