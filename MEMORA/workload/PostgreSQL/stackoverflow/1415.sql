
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT p.Tags) AS UniqueTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
CommentStats AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.UserId
),
VotingStats AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.Views,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(ps.PostCount, 0) AS TotalPosts,
    COALESCE(ps.Questions, 0) AS TotalQuestions,
    COALESCE(ps.Answers, 0) AS TotalAnswers,
    COALESCE(ps.AvgScore, 0) AS AverageScore,
    COALESCE(ps.UniqueTags, 0) AS UniqueTagsCount,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COALESCE(vs.VoteCount, 0) AS TotalVotes,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes
FROM 
    UserStats us
LEFT JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
LEFT JOIN 
    CommentStats cs ON us.UserId = cs.UserId
LEFT JOIN 
    VotingStats vs ON us.UserId = vs.UserId
ORDER BY 
    us.Reputation DESC,
    us.Views DESC;
