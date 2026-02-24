
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostBenchmarking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
)
SELECT 
    upc.DisplayName,
    upc.PostCount,
    upc.TotalScore,
    upc.QuestionCount,
    upc.AnswerCount,
    pb.PostId,
    pb.Title,
    pb.CreationDate,
    pb.Score,
    pb.ViewCount,
    pb.CommentCount,
    pb.VoteCount
FROM 
    UserPostCounts upc
JOIN 
    PostBenchmarking pb ON upc.UserId = pb.OwnerUserId
ORDER BY 
    upc.TotalScore DESC, 
    upc.PostCount DESC;
