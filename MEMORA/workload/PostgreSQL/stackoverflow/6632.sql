WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(
            CASE 
                WHEN p.PostTypeId = 1 THEN 1 
                ELSE 0 
            END
        ) AS QuestionCount,
        SUM(
            CASE 
                WHEN p.PostTypeId = 2 THEN 1 
                ELSE 0 
            END
        ) AS AnswerCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        RANK() OVER (ORDER BY UpVotesCount DESC) AS UpvotesRank
    FROM 
        UserVoteStats
    WHERE 
        TotalVotes > 0
),
ActivePosts AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.AverageScore,
        tu.DisplayName AS TopUser
    FROM 
        PostStatistics ps
    JOIN 
        Votes v ON ps.PostId = v.PostId
    JOIN 
        TopUsers tu ON v.UserId = tu.UserId
    WHERE 
        ps.CommentCount > 10 AND ps.AverageScore > 5
)
SELECT 
    ap.PostId,
    ap.CommentCount,
    ap.QuestionCount,
    ap.AnswerCount,
    ap.AverageScore,
    COUNT(DISTINCT ap.TopUser) AS UniqueTopUsers
FROM 
    ActivePosts ap
GROUP BY 
    ap.PostId, ap.CommentCount, ap.QuestionCount, ap.AnswerCount, ap.AverageScore
ORDER BY 
    UniqueTopUsers DESC, ap.AverageScore DESC
LIMIT 100;
