WITH UserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgesCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VotesCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(up.PostsCount, 0) AS TotalPosts,
    COALESCE(up.QuestionsCount, 0) AS TotalQuestions,
    COALESCE(up.AnswersCount, 0) AS TotalAnswers,
    COALESCE(up.AverageScore, 0) AS AveragePostScore,
    COALESCE(ub.BadgesCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(uvs.VotesCount, 0) AS TotalVotes,
    COALESCE(uvs.UpVotesCount, 0) AS TotalUpVotes,
    COALESCE(uvs.DownVotesCount, 0) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    UserPosts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    UserVoteStats uvs ON u.Id = uvs.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC
LIMIT 50;
