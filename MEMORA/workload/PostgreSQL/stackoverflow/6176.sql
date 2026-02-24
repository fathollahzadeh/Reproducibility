WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
AggregatedStats AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
)
SELECT 
    COUNT(*) AS TotalPosts, 
    AVG(CommentCount) AS AvgComments, 
    AVG(UpVotes) AS AvgUpVotes, 
    AVG(DownVotes) AS AvgDownVotes, 
    AVG(NetVotes) AS AvgNetVotes
FROM 
    AggregatedStats
WHERE 
    CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month';