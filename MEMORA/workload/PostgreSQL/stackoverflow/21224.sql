WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
),
VisiblePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        pha.FirstEditDate,
        pha.EditCount,
        pha.CloseCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS PostRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistoryAnalysis pha ON rp.PostId = pha.PostId
    WHERE 
        rp.OwnerPostRank = 1 
    ORDER BY 
        u.Reputation DESC, rp.Score DESC
),
FinalResults AS (
    SELECT 
        vp.*,
        CASE 
            WHEN vp.CloseCount > 0 THEN 'Closed'
            WHEN vp.EditCount > 0 THEN 'Edited'
            ELSE 'Original'
        END AS PostStatus,
        CASE 
            WHEN vp.OwnerReputation >= 1000 THEN 'Experienced'
            WHEN vp.OwnerReputation < 0 THEN 'Novice'
            ELSE 'Intermediate'
        END AS OwnerExperienceLevel
    FROM 
        VisiblePosts vp
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.PostStatus,
    fr.OwnerExperienceLevel
FROM 
    FinalResults fr
WHERE 
    fr.PostRank <= 50 
ORDER BY 
    fr.OwnerExperienceLevel, fr.PostRank;