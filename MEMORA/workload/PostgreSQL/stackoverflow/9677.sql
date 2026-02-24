
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
), FilteredPosts AS (
    SELECT 
        rp.*,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 10 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Author,
    fp.CommentCount,
    fp.NetVotes
FROM 
    FilteredPosts fp
ORDER BY 
    fp.NetVotes DESC, fp.CreationDate DESC;
