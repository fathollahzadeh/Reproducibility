
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
UserBadgeActivity AS (
    SELECT 
        ub.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges ub
    GROUP BY 
        ub.UserId
),
PostTypeCounts AS (
    SELECT
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
FinalActivity AS (
    SELECT 
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.QuestionsCount,
        ua.AnswersCount,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        COALESCE(uba.BadgeCount, 0) AS BadgeCount,
        pt.Questions,
        pt.Answers,
        MAX(ua.LastActivityDate) AS LastActive
    FROM 
        UserActivity ua
    LEFT JOIN 
        UserBadgeActivity uba ON ua.UserId = uba.UserId
    LEFT JOIN 
        PostTypeCounts pt ON ua.UserId = pt.OwnerUserId
    GROUP BY 
        ua.UserId, ua.DisplayName, ua.TotalPosts, 
        ua.TotalComments, ua.QuestionsCount, ua.AnswersCount, 
        ua.TotalUpVotes, ua.TotalDownVotes, uba.BadgeCount, 
        pt.Questions, pt.Answers
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalComments,
    QuestionsCount,
    AnswersCount,
    TotalUpVotes,
    TotalDownVotes,
    BadgeCount,
    Questions,
    Answers,
    LastActive
FROM 
    FinalActivity
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC
LIMIT 10;
