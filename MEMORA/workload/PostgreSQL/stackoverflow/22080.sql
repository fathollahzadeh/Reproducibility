
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
QualifiedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS NetVotes,
        TotalPosts,
        TotalComments,
        QuestionsCount,
        AnswersCount,
        RANK() OVER (ORDER BY UpVotes DESC) AS VoteRank,
        ROW_NUMBER() OVER (PARTITION BY QuestionsCount ORDER BY AnswersCount DESC) AS QuestionAnswerRank
    FROM 
        UserPostStats
    WHERE 
        (UpVotes - DownVotes) > 10 AND 
        TotalPosts > 5
),
SuspiciousBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS SuspiciousBadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 3 AND 
        b.Date < (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        u.Id
)
SELECT 
    q.UserId,
    q.DisplayName,
    q.NetVotes,
    q.QuestionsCount,
    q.AnswersCount,
    COALESCE(sb.SuspiciousBadgeCount, 0) AS SuspiciousBadgeCount,
    q.VoteRank,
    q.QuestionAnswerRank,
    CASE 
        WHEN q.AnswersCount = 0 THEN 'No Answers Yet'
        WHEN q.QuestionsCount > 0 AND q.AnswersCount < 3 THEN 'Less than 3 Answers'
        ELSE 'Well-Answered'
    END AS AnswerStatus,
    CASE 
        WHEN sb.SuspiciousBadgeCount > 0 THEN 'Suspicious User'
        ELSE 'Clean User'
    END AS UserStatus
FROM 
    QualifiedUsers q
LEFT JOIN 
    SuspiciousBadges sb ON q.UserId = sb.UserId
WHERE 
    (q.NetVotes >= 0 OR (q.AnswersCount > 5 AND q.TotalComments > 10))
ORDER BY 
    q.NetVotes DESC,
    q.VoteRank,
    UserStatus;
