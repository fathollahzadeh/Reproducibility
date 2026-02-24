
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
             PostId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
         FROM 
             Votes 
         GROUP BY 
             PostId) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.Tags,
        r.CreationDate,
        r.OwnerUserId,
        r.OwnerDisplayName,
        r.UpVotes,
        r.DownVotes,
        (r.UpVotes - r.DownVotes) AS NetScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    WHERE 
        r.Rank <= 5 
    GROUP BY 
        r.PostId, r.Title, r.Body, r.Tags, r.CreationDate, r.OwnerUserId, r.OwnerDisplayName, r.UpVotes, r.DownVotes, r.Rank
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.UpVotes,
    fp.DownVotes,
    fp.NetScore,
    fp.CommentCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.NetScore DESC, 
    fp.CreationDate DESC;
