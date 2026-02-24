
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteStats pvs ON rp.PostId = pvs.PostId
    WHERE 
        rp.RN <= 5
)
SELECT 
    pp.Title,
    pp.CreationDate,
    pp.OwnerDisplayName,
    pp.UpVotes,
    pp.DownVotes,
    COALESCE((SELECT SUM(B.Count) 
               FROM Tags B 
               WHERE B.WikiPostId = pp.PostId
              ), 0) AS TagCount,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureCount
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistory ph ON pp.PostId = ph.PostId
GROUP BY 
    pp.PostId, pp.Title, pp.CreationDate, pp.OwnerDisplayName, pp.UpVotes, pp.DownVotes
ORDER BY 
    pp.UpVotes DESC, pp.CreationDate DESC;
