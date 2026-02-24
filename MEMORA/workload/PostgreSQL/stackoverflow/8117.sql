
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC) AS RankByAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN pts.Id = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN pts.Id = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTypes pts ON p.PostTypeId = pts.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    mau.UserName,
    mau.PostCount,
    mau.QuestionsCount,
    mau.AnswersCount
FROM 
    RankedPosts rp
LEFT JOIN 
    MostActiveUsers mau ON rp.Author = mau.UserName
WHERE 
    rp.RankByAnswers <= 10
ORDER BY 
    rp.RankByAnswers;
