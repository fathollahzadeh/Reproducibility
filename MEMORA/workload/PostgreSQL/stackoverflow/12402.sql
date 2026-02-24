WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        pt.Name AS PostType,
        pt.Id AS PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, u.Reputation, p.Title, p.CreationDate, pt.Name, pt.Id
)

SELECT 
    PostId,
    Title,
    CreationDate,
    OwnerReputation,
    CommentCount,
    UpVotes,
    DownVotes,
    CASE 
        WHEN PostTypeId = 1 THEN 'Question'
        WHEN PostTypeId IN (2, 3) THEN 'Answer'
        ELSE 'Other'
    END AS PostCategory
FROM 
    BenchmarkData
ORDER BY 
    OwnerReputation DESC, CreationDate DESC
LIMIT 100;
