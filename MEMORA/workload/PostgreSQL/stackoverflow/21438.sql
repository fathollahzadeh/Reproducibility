WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts AS p
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.AcceptedAnswerId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(rp.UpVotes) AS TotalUpVotes,
        COUNT(rp.Id) AS TotalPosts
    FROM 
        Users AS u
    JOIN 
        RankedPosts AS rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(rp.Id) > 5 AND SUM(rp.UpVotes) > 10
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory AS ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        COALESCE(cr.CloseReason, 'Not Closed') AS LastCloseReason,
        COALESCE(cr.CloseCount, 0) AS NumberOfClosures
    FROM 
        TopUsers AS tu
    LEFT JOIN 
        CloseReasons AS cr ON cr.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = tu.UserId)
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    fr.LastCloseReason,
    fr.NumberOfClosures,
    CASE 
        WHEN fr.NumberOfClosures > 0 THEN 'Has Closed Posts'
        ELSE 'No Closed Posts'
    END AS ClosureStatus,
    CONCAT('User ', fr.DisplayName, ' has ', fr.NumberOfClosures, ' closed posts.') AS ClosureMessage
FROM 
    FinalResults AS fr
ORDER BY 
    fr.Reputation DESC, fr.UserId;