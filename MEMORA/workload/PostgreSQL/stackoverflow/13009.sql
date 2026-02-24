WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(cb.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges cb ON u.Id = cb.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        AnswerCount, 
        QuestionCount, 
        UpVoteCount, 
        DownVoteCount, 
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC, UpVoteCount DESC) AS Rank
    FROM 
        UserStats
)
SELECT
    UserId,
    DisplayName,
    PostCount,
    AnswerCount,
    QuestionCount,
    UpVoteCount,
    DownVoteCount,
    BadgeCount
FROM 
    TopUsers
WHERE 
    Rank <= 10 
ORDER BY 
    Rank;