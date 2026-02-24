WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCount,
        QuestionsCount,
        AnswersCount,
        UpVotesCount,
        DownVotesCount,
        LastPostDate,
        RANK() OVER (ORDER BY PostsCount DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        PostsCount > 0
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.PostsCount,
    t.QuestionsCount,
    t.AnswersCount,
    t.UpVotesCount,
    t.DownVotesCount,
    t.LastPostDate,
    ROUND(COALESCE(NULLIF(t.UpVotesCount, 0), 1) / NULLIF(t.AnswersCount, 0), 2) AS UpVoteToAnswerRatio,
    ROUND(COALESCE(NULLIF(t.DownVotesCount, 0), 1) / NULLIF(t.QuestionsCount, 0), 2) AS DownVoteToQuestionRatio
FROM 
    TopActiveUsers t
WHERE 
    t.UserRank <= 10
ORDER BY 
    t.UserRank;
