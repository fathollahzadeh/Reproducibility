
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId, p.Score
),
FilteredPosts AS (
    SELECT 
        PostId, Title, CreationDate, OwnerName, CommentCount, UpVoteCount, DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    fp.Title, 
    fp.CreationDate, 
    fp.OwnerName, 
    fp.CommentCount, 
    fp.UpVoteCount, 
    fp.DownVoteCount, 
    (fp.UpVoteCount - fp.DownVoteCount) AS NetVotes,
    CASE 
        WHEN fp.CommentCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityState
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVoteCount DESC, 
    fp.CommentCount DESC;
