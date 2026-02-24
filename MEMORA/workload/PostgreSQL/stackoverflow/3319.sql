WITH UserVotes AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(v.Id) AS TotalVotes, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Unanswered' 
        END AS PostStatus,
        u.Id AS OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - interval '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.PostStatus,
    pd.OwnerUserId,
    pd.OwnerDisplayName,
    COALESCE(up.TotalVotes, 0) AS UserTotalVotes,
    COALESCE(up.UpVotes, 0) AS UserUpVotes,
    COALESCE(up.DownVotes, 0) AS UserDownVotes,
    cp.FirstClosedDate,
    EXTRACT(EPOCH FROM (cp.FirstClosedDate - pd.CreationDate)) AS TimeToClose 
FROM 
    PostDetails pd
LEFT JOIN 
    UserVotes up ON pd.OwnerUserId = up.UserId
LEFT JOIN 
    ClosedPosts cp ON pd.PostId = cp.PostId
WHERE 
    pd.Rank = 1
    AND (pd.PostStatus = 'Answered' OR pd.PostStatus = 'Unanswered')
ORDER BY 
    pd.CreationDate DESC;