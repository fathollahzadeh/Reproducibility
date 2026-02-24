
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(t.TagName, 'Uncategorized') AS MainTag
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL (
        SELECT 
            UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS TagName
    ) t ON TRUE
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount, p.AnswerCount, t.TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) AS NumberOfEdits,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS EditComments
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(b.Class) / NULLIF(COUNT(DISTINCT b.Id), 0), 0) AS AverageBadgeClass
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserPostRank,
        phs.NumberOfEdits,
        phs.EditComments,
        ur.TotalBadgeClass,
        ur.BadgeCount,
        ur.AverageBadgeClass
    FROM RankedPosts rp
    LEFT JOIN PostHistorySummary phs ON rp.Id = phs.PostId
    LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.UserPostRank,
    COALESCE(pd.NumberOfEdits, 0) AS TotalEdits,
    pd.EditComments,
    pd.TotalBadgeClass,
    pd.BadgeCount,
    pd.AverageBadgeClass,
    CASE 
        WHEN pd.Score > 100 THEN 'Highly Popular'
        WHEN pd.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM PostDetails pd
WHERE pd.UserPostRank <= 5 
ORDER BY pd.Score DESC, pd.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
