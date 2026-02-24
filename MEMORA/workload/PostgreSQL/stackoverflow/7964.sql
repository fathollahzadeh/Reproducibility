
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        TotalBadges,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalBadges DESC) AS UserRank
    FROM 
        UserStatistics
)
SELECT 
    UserRank,
    DisplayName,
    QuestionCount,
    AnswerCount,
    CommentCount,
    TotalBadges,
    UpVotes,
    DownVotes
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
