
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        COUNT(DISTINCT t.Id) AS TagCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN v.VoteTypeId = 11 THEN 1 ELSE 0 END) AS OpenVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostCreationDate,
    rp.UserId,
    rp.UserDisplayName,
    rp.TagCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.CloseVotes,
    rp.OpenVotes
FROM 
    RecentPosts rp
ORDER BY 
    rp.PostCreationDate DESC
LIMIT 100;
