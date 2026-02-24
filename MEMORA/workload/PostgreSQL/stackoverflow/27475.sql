
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount,
        SUM(pt.AnswerCount) AS TotalAnswers,
        AVG(pt.UpVotes - pt.DownVotes) AS NetVotes
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        RankedPosts pt ON pt.PostId = p.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalAnswers,
        NetVotes,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS RankByAnswers,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts,
        RANK() OVER (ORDER BY NetVotes DESC) AS RankByNetVotes
    FROM 
        TagStatistics
)
SELECT 
    TagName,
    PostCount,
    TotalAnswers,
    NetVotes,
    CASE 
        WHEN RankByAnswers = 1 THEN 'Top'
        WHEN RankByAnswers <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS AnswerRank,
    CASE 
        WHEN RankByPosts = 1 THEN 'Top'
        WHEN RankByPosts <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS PostRank,
    CASE 
        WHEN RankByNetVotes = 1 THEN 'Top'
        WHEN RankByNetVotes <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS VoteRank
FROM 
    TopTags
WHERE 
    PostCount > 10 
ORDER BY 
    NetVotes DESC, TotalAnswers DESC;
