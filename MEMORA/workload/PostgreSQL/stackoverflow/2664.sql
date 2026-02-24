
WITH UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'Favorite' THEN 1 ELSE 0 END) AS Favorites
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id
),
TopAnsweredQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.AcceptedAnswerId
),
MainQuery AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(vs.TotalVotes, 0) AS TotalVotes,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.Favorites, 0) AS Favorites,
        aq.AnswerCount
    FROM 
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserVoteStats vs ON u.Id = vs.UserId
    LEFT JOIN TopAnsweredQuestions aq ON p.Id = aq.Id
)
SELECT 
    PostId, 
    Title,
    CreationDate, 
    OwnerName,
    TotalVotes,
    UpVotes,
    DownVotes,
    Favorites,
    AnswerCount,
    MAX(CASE WHEN AnswerCount IS NOT NULL THEN AnswerCount ELSE 0 END) OVER () AS MaxAnswerCount
FROM 
    MainQuery
WHERE 
    (TotalVotes > 0 OR AnswerCount > 0)
ORDER BY 
    AnswerCount DESC, 
    CreationDate DESC
LIMIT 10;
