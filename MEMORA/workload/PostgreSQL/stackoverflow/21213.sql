WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        RankedPosts rp ON v.PostId = rp.PostId
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEdited,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.AcceptedAnswerId IS NULL
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        pv.UpVotes,
        pv.DownVotes,
        ub.BadgeCount,
        ph.LastEdited,
        ph.CloseReason,
        ph.EditCount,
        ARRAY_LENGTH(string_to_array(rp.Tags, ','), 1) AS TagCount,
        CASE 
            WHEN EXISTS (SELECT 1 FROM PostLinks pl WHERE pl.PostId = rp.PostId) 
            THEN TRUE 
            ELSE FALSE 
        END AS HasLinks
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN 
        UserBadges ub ON rp.PostId = ub.UserId
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    UpVotes,
    DownVotes,
    BadgeCount,
    LastEdited,
    CloseReason,
    EditCount,
    TagCount,
    HasLinks
FROM 
    FinalResults
WHERE 
    (UpVotes - DownVotes) > 0 
    AND TagCount > 1 
    AND (LastEdited IS NULL OR LastEdited >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    Score DESC,
    CreationDate ASC
LIMIT 100;