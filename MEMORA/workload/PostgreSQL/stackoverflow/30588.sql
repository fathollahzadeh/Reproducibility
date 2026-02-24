
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
),
TopTags AS (
    SELECT 
        t.TagName,
        t.Count,
        RANK() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM Tags t
    WHERE t.Count > 100 
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) AS ClosureEvents
    FROM PostHistory ph
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        tt.TagName,
        pv.PostId,
        pv.Title,
        pv.CreationDate,
        pv.Upvotes,
        pv.Downvotes,
        ph.LastClosedDate,
        ph.ClosureEvents,
        CASE 
            WHEN ph.LastClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM RankedUsers u
    CROSS JOIN TopTags tt
    JOIN PostsWithVotes pv ON u.UserId = pv.PostId 
    LEFT JOIN PostHistoryAggregates ph ON pv.PostId = ph.PostId
    WHERE u.UserRank <= 10 
    AND tt.TagRank <= 5   
)
SELECT 
    fr.DisplayName AS UserDisplayName,
    fr.TagName,
    fr.Title,
    fr.CreationDate,
    fr.Upvotes,
    fr.Downvotes,
    fr.PostStatus,
    COALESCE(fr.ClosureEvents, 0) AS NumberOfClosures
FROM FinalResults fr
ORDER BY fr.DisplayName, fr.TagName;
