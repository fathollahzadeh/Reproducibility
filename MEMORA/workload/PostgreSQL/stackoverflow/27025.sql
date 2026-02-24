
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (UpVotes - DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY UpVotes DESC) AS VoteRank
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 10  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.CommentCount,
    fp.AnswerCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.NetVotes,
    fp.Rank,
    fp.VoteRank
FROM 
    FilteredPosts fp
WHERE 
    (Tags IS NOT NULL AND Tags <> '') 
    AND POSITION('sql' IN LOWER(fp.Body)) > 0 
ORDER BY 
    fp.NetVotes DESC, fp.CreationDate DESC;
