
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN b.Id IS NOT NULL THEN 1 END) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        BadgeCount
    FROM 
        UserStats
    WHERE 
        PostRank <= 10
)
SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.QuestionCount,
    t.AnswerCount,
    t.UpVotes,
    t.DownVotes,
    t.BadgeCount,
    COALESCE(
        (SELECT SUM(CASE WHEN ph.CreationDate IS NOT NULL THEN 1 ELSE 0 END) 
         FROM PostHistory ph
         WHERE ph.UserId = t.UserId), 
        0) AS PostEdits,
    COALESCE(
        (SELECT COUNT(DISTINCT c.Id)
         FROM Comments c
         JOIN Posts po ON c.PostId = po.Id
         WHERE po.OwnerUserId = t.UserId), 
        0) AS TotalComments
FROM 
    TopUsers t
ORDER BY 
    (t.UpVotes - t.DownVotes) DESC, 
    t.BadgeCount DESC;
