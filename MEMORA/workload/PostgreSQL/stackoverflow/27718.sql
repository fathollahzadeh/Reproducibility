WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankWithinTag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pht.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Text AS ChangeDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ue.DisplayName AS OwnerDisplayName,
    ue.TotalVotes,
    ue.UpVotes,
    ue.DownVotes,
    rp.RankWithinTag,
    ph.CreationDate AS LastChangeDate,
    ph.ChangeType,
    ph.UserDisplayName AS ChangerDisplayName,
    ph.ChangeDetails
FROM 
    RankedPosts rp
LEFT JOIN 
    UserEngagement ue ON rp.OwnerUserId = ue.UserId
LEFT JOIN 
    RecentPostHistory ph ON rp.PostId = ph.PostId
WHERE 
    rp.RankWithinTag <= 5 
ORDER BY 
    rp.Tags, rp.Score DESC;