WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), 
TopVoters AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.Owner,
    COALESCE(tv.VoteCount, 0) AS TotalVotes,
    COALESCE(tv.UpVotes, 0) AS UpVotes,
    COALESCE(tv.DownVotes, 0) AS DownVotes,
    COALESCE(pha.EditCount, 0) AS EditCount,
    pha.LastEditDate,
    CASE 
        WHEN rp.Score IS NULL THEN 'No score yet'
        WHEN rp.Score > 10 THEN 'Popular'
        ELSE 'Needs more engagement'
    END AS EngagementLevel
FROM 
    RecentPosts rp
LEFT JOIN 
    TopVoters tv ON rp.PostId = tv.PostId
LEFT JOIN 
    PostHistoryAggregate pha ON rp.PostId = pha.PostId
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;