WITH UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Votes V
    JOIN Users U ON V.UserId = U.Id
    GROUP BY V.UserId
), UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
), PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Posts P2 WHERE P2.ParentId = P.Id AND P2.PostTypeId = 2), 0) AS AnswerCount,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAcceptedAnswerExists
    FROM Posts P
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.CreationDate AS UserCreationDate,
    U.LastAccessDate,
    COALESCE(UB.BadgeNames, 'No Badges') AS UserBadges,
    UV.UpVoteCount,
    UV.DownVoteCount,
    UV.TotalBounty,
    COUNT(DISTINCT PD.PostId) AS PostCount,
    COUNT(DISTINCT CASE WHEN PD.IsAcceptedAnswerExists = 1 THEN PD.PostId END) AS AcceptedAnswers,
    SUM(PD.Score) AS TotalScore,
    SUM(PD.ViewCount) AS TotalViews,
    SUM(PD.CommentCount) AS TotalComments,
    STRING_AGG(DISTINCT PD.Title, '; ') AS PostTitles
FROM Users U
LEFT JOIN UserVotes UV ON U.Id = UV.UserId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostDetails PD ON U.Id = PD.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.Views, U.CreationDate, U.LastAccessDate, UB.BadgeNames, UV.UpVoteCount, UV.DownVoteCount, UV.TotalBounty
HAVING 
    SUM(PD.ViewCount) > 1000 OR COUNT(DISTINCT PD.PostId) > 10
ORDER BY 
    U.Reputation DESC,
    U.LastAccessDate DESC;
