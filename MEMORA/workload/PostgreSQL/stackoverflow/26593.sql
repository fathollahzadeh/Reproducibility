
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS AuthorName,
        u.Reputation AS AuthorReputation,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '> <')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        ViewCount, 
        AnswerCount, 
        AuthorName, 
        AuthorReputation,
        TagsList,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS Rank
    FROM 
        PostDetails
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 END) AS AcceptedCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.AuthorName,
    tp.AuthorReputation,
    tp.TagsList,
    vs.UpVotes,
    vs.DownVotes,
    vs.AcceptedCount
FROM 
    TopPosts tp
JOIN 
    VoteSummary vs ON tp.PostId = vs.PostId
WHERE 
    tp.Rank <= 10  
ORDER BY 
    tp.ViewCount DESC;
