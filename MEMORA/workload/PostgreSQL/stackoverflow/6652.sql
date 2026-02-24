WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        MAX(p.CreationDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostSummaries AS (
    SELECT 
        DISTINCT p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        COALESCE(SUM(c.CommentCount), 0) AS CommentCount,
        COALESCE(SUM(v.UpVoteCount), 0) AS TotalUpVotes,
        COALESCE(SUM(v.DownVoteCount), 0) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    uBad.GoldBadges,
    uBad.SilverBadges,
    uBad.BronzeBadges,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpvoteCount,
    ua.DownvoteCount,
    ua.LastActiveDate,
    ps.Title AS PostTitle,
    ps.PostCreationDate,
    ps.CommentCount,
    ps.TotalUpVotes,
    ps.TotalDownVotes
FROM 
    UserActivity ua
LEFT JOIN 
    UserBadges uBad ON ua.UserId = uBad.UserId
LEFT JOIN 
    PostSummaries ps ON ua.UserId = ps.PostId
WHERE 
    ua.Reputation > 1000
ORDER BY 
    ua.Reputation DESC, 
    ua.LastActiveDate DESC
LIMIT 100;
