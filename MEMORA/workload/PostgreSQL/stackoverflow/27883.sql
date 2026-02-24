
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.CommentCount,
        ua.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ua.Reputation DESC) AS Rank
    FROM 
        UserActivity ua
    WHERE 
        ua.Reputation > 100
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.Tags,
        ARRAY_AGG(DISTINCT pi.LinkTypeId) AS RelatedLinkTypes,
        COUNT(c.Id) AS TotalComments,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pi ON p.Id = pi.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.Tags
),
ActivitySummary AS (
    SELECT 
        p.Title,
        COUNT(DISTINCT v.UserId) AS UniqueViewers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Title
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.AnswerCount,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.ViewCount,
    ps.Score,
    ps.Tags,
    asu.UniqueViewers,
    asu.UpVotes,
    asu.DownVotes,
    asu.LastActivityDate
FROM 
    TopUsers tu
JOIN 
    PostStatistics ps ON ps.ViewCount > 100
JOIN 
    ActivitySummary asu ON ps.Title = asu.Title
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
