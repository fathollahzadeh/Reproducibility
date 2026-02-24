
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVoteCount,
        DownVoteCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY UpVoteCount DESC) AS UpVoteRank
    FROM 
        UserPostStats
), CombinedRanked AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVoteCount,
        DownVoteCount,
        PostRank,
        UpVoteRank,
        (PostRank + UpVoteRank) AS CombinedRank
    FROM 
        RankedUsers
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    AnswerCount,
    QuestionCount,
    UpVoteCount,
    DownVoteCount,
    CombinedRank
FROM 
    CombinedRanked
WHERE 
    CombinedRank <= 10
ORDER BY 
    CombinedRank;
