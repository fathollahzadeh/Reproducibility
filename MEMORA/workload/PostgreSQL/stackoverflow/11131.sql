WITH PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(pvc.VoteCount, 0) AS VoteCount,
    COALESCE(pvc.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(pvc.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(upc.PostCount, 0) AS OwnerPostCount,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
LEFT JOIN 
    PostVoteCounts pvc ON p.Id = pvc.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserPostCounts upc ON u.Id = upc.UserId
ORDER BY 
    p.CreationDate DESC
LIMIT 100;